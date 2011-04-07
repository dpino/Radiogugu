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
      @radio = save_as_user_copy(@radio)
    end

    genders = retrieve_or_create_genders_DB(params[:radio][:gender])
    # genders = associate_genders_with_user(genders)

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

  def retrieve_or_create_genders_DB(genders)
    result = Array.new
    genders.split(" ").each { |gender|
      record = Gender.where("name = ?", gender)
      if (record.empty?)
        record = Gender.new(:name => gender)
        record.save
      end
      result << record
    }
    return result
  end

  #def associate_genders_with_user(genders)
  #  genders.each { |gender|
  #
  #  }
  #end

  def save_as_user_copy(radio)
    newRadio = radio.clone
    newRadio.user = current_user
    newRadio.parent = radio
    newRadio.save
    # save_tags(newRadio)
    return newRadio
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
