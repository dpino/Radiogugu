class RadiosController < ApplicationController
  # GET /radios
  # GET /radios.xml
  def index
    @radios = all_radios()
    @active_tab = :gender

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @radios }
    end
  end

  def all_radios()
    return current_user == nil ? Radio.all : all_radios_for_user()
  end

  def all_radios_for_user(radios)
    user_radios = Radio.where("user_id = ?", current_user.id)
    original_radios = Radio.where("user_id = null AND id NOT IN (?)", user_radios)
    return original_radios + user_radios
  end

  # GET /radios/1
  # GET /radios/1.xml
  def show
    @radio = Radio.find(params[:id])
    @is_favorite = is_favorite(@radio.id)
    @active_tab = :gender

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @radio }
    end
  end

  def is_favorite(radio_id)
    if (current_user != nil)
      return Favorite.exists?(["user_id = ? AND radio_id = ?", current_user.id, radio_id])
    end
    return false
  end

  # GET /radios/new
  # GET /radios/new.xml
  def new
    @radio = Radio.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @radio }
    end
  end

  # GET /radios/1/edit
  def edit
    @radio = Radio.find(params[:id])
  end

  # POST /radios
  # POST /radios.xml
  def create
    @radio = Radio.new(params[:radio])

    respond_to do |format|
      if @radio.save
        format.html { redirect_to(@radio, :notice => 'Radio was successfully created.') }
        format.xml  { render :xml => @radio, :status => :created, :location => @radio }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @radio.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /radios/1
  # PUT /radios/1.xml
  def update
    @radio = Radio.find(params[:id])

    # User not logged, cannot modify radio
    return if (current_user == nil)

    # User logged, but modifying original radio
    if (@radio.user == nil)
      @radio = retrieve_or_create_child(@radio)
    end

    # Prepare genders and save them
    genders = retrieve_or_create_genders_DB(params[:radio][:gender])
    if (!genders.empty?)
      genders_radio = associate_genders_with_radio_and_user(genders)
      save_genders_for_radio(genders_radio)
    end

    respond_to do |format|
      if @radio.update_attributes(params[:radio])
        format.html { redirect_to(@radio, :notice => 'Radio was successfully updated.') }
        format.xml  { head :ok }
        format.json { render :json => @radio, :status => :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @radio.errors, :status => :unprocessable_entity }
        format.json { render :json => @radio, :status => :ok }
      end
    end
  end

  def save_genders_for_radio(genders_radio)
    # Check if there are radios for this radio and user, in that case remove them
    GendersRadio.delete_all(["user_id = ? and radio_id = ?", current_user.id, @radio.id]);
    genders_radio.each { |gender_radio|
      gender_radio.save
    }
  end

  def retrieve_or_create_genders_DB(genders)
    result = Array.new
    genders.split(" ").each { |gender|
      record = Gender.where("name = ?", gender).first
      if (record == nil)
        record = Gender.new(:name => gender)
        record.save
      end
      result << record
    }
    return result
  end

  def associate_genders_with_radio_and_user(genders)
    result = Array.new
    genders.each { |gender|
      gender_radio = GendersRadio.new
      gender_radio.gender_id = gender.id
      gender_radio.radio_id = @radio.id
      gender_radio.user_id = current_user.id
      result << gender_radio
    }
    return result
  end

  def retrieve_or_create_child(radio)
    # Check if the user already has a child for this radio
    user_radio = @radio.get_child(current_user)
    if (user_radio == nil)
      return radio.create(current_user)
    end
    # In case it had, update child with params
    user_radio.update_attributes(params[:radio]);
    return user_radio
  end

  # DELETE /radios/1
  # DELETE /radios/1.xml
  def destroy
    @radio = Radio.find(params[:id])
    @radio.destroy

    respond_to do |format|
      format.html { redirect_to(radios_url) }
      format.xml  { head :ok }
    end
  end
end
