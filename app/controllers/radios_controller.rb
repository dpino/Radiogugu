class RadiosController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create_transcript_chunk]

  def index
    @radios = all_radios
    @active_tab = :gender

    respond_to do |format|
      format.html
      format.xml { render xml: @radios }
    end
  end

  def all_radios
    current_user.nil? ? Radio.all : all_radios_for_user
  end

  def all_radios_for_user
    user_radios = Radio.where(user_id: current_user.id)
    original_radios = Radio.where(user_id: nil).where.not(id: user_radios.select(:parent_id))
    original_radios.to_a + user_radios.to_a
  end

  def redirect_to_child_if_any(radio_id)
    return if current_user.nil?

    user_radio = Radio.where(user_id: current_user.id, parent_id: radio_id).first
    if user_radio
      redirect_to radio_path(user_radio)
    end
  end

  # GET /radios/1
  def show
    # If user is logged, check if there's a child for this radio
    # and redirect to it if that's the case
    radio_id = params[:id]
    redirect_to_child_if_any(radio_id)
    return if performed?

    @radio = Radio.find(radio_id)
    @is_favorite = is_favorite(@radio.id) if @radio
    @active_tab = :gender

    respond_to do |format|
      format.html
      format.xml { render xml: @radio }
    end
  end

  def is_favorite(radio_id)
    return false unless current_user

    Favorite.exists?(user_id: current_user.id, radio_id: radio_id)
  end

  # GET /radios/1/now_playing
  #
  # Fetched server-side rather than straight from the browser: even when a
  # stream host allows cross-origin reads of the audio itself, browsers still
  # hide the icy-metaint response header from JS unless the host also sends
  # Access-Control-Expose-Headers, which in practice almost none of them do.
  def now_playing
    radio = Radio.find(params[:id])
    render json: { title: IcyNowPlaying.fetch_title(radio.url) }
  end

  # GET /radios/1/transcript
  #
  # Prototype: live, local speech-to-text of the stream, produced out of band
  # by script/transcribe.py (not by the Rails app itself) and stored here.
  # Only ever has data for whichever station that script is currently
  # pointed at - for every other radio this just returns an empty list.
  def transcript
    radio = Radio.find(params[:id])
    since_id = params[:since_id].presence&.to_i || 0

    lines = radio.transcripts.where("id > ?", since_id).order(:id).limit(50)
    render json: {
      lines: lines.map { |t| { id: t.id, text: t.text, started_at: t.started_at } },
    }
  end

  # POST /radios/1/transcript_chunks
  #
  # Called by script/transcribe.py, authenticated with a shared secret
  # (TRANSCRIBE_TOKEN) rather than a user session - this is a local
  # background script, not a browser request.
  def create_transcript_chunk
    expected = ENV["TRANSCRIBE_TOKEN"]
    head :unauthorized and return if expected.blank? || request.headers["X-Transcribe-Token"] != expected

    radio = Radio.find(params[:id])
    radio.transcripts.create!(
      text: params.require(:text),
      started_at: params[:started_at],
      ended_at: params[:ended_at]
    )
    head :ok
  end

  def new
    @radio = Radio.new

    respond_to do |format|
      format.html
      format.xml { render xml: @radio }
    end
  end

  def edit
    @radio = Radio.find(params[:id])
  end

  def create
    @radio = Radio.new(radio_params)

    respond_to do |format|
      if @radio.save
        format.html { redirect_to(@radio, notice: "Radio was successfully created.") }
        format.xml { render xml: @radio, status: :created, location: @radio }
      else
        format.html { render action: "new" }
        format.xml { render xml: @radio.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @radio = Radio.find(params[:id])
    original_radio_id = @radio.id

    # User not logged, cannot modify radio
    return if current_user.nil?

    # User logged, but modifying original radio
    if @radio.user.nil?
      @radio = retrieve_or_create_child(@radio)
    end

    # Prepare genders and save them
    genders = retrieve_or_create_genders_db(params.dig(:radio, :gender))
    if genders.present?
      genders_radio = associate_genders_with_radio_and_user(genders)
      save_genders_for_radio(genders_radio)
    end

    respond_to do |format|
      if @radio.update(radio_params)
        format.html { redirect_to(@radio, notice: "Radio was successfully updated.") }
        format.xml { head :ok }
        format.json do
          if original_radio_id == @radio.id
            render json: @radio
          else
            render json: { redirect_to: @radio.id }
          end
        end
      else
        format.html { render action: "edit" }
        format.xml { render xml: @radio.errors, status: :unprocessable_entity }
        format.json { render json: @radio, status: :ok }
      end
    end
  end

  def save_genders_for_radio(genders_radio)
    # Check if there are radios for this radio and user, in that case remove them
    GendersRadio.where(user_id: current_user.id, radio_id: @radio.id).delete_all
    genders_radio.each(&:save)
  end

  def retrieve_or_create_genders_db(genders)
    return [] if genders.blank?

    genders.split(" ").map do |gender|
      Gender.find_or_create_by(name: gender)
    end
  end

  def associate_genders_with_radio_and_user(genders)
    genders.map do |gender|
      GendersRadio.new(gender_id: gender.id, radio_id: @radio.id, user_id: current_user.id)
    end
  end

  def retrieve_or_create_child(radio)
    # Check if the user already has a child for this radio
    user_radio = @radio.get_child(current_user)
    if user_radio.nil?
      return radio.fork(current_user)
    end

    # In case it had, update child with params
    user_radio.update(radio_params)
    user_radio
  end

  def destroy
    @radio = Radio.find(params[:id])
    @radio.destroy

    respond_to do |format|
      format.html { redirect_to(radios_url) }
      format.xml { head :ok }
    end
  end

  private

  def radio_params
    params.require(:radio).permit(:name, :website, :url, :gender, :location_id)
  end
end
