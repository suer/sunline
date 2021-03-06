class ScriptsController < ApplicationController
  before_action :set_script, only: [:edit, :update, :destroy, :archive, :unarchive, :grep]
  skip_filter :authenticate_user!, only: [:sh, :wrapped_sh]

  # GET /scripts
  # GET /scripts.json
  def index
    if params[:archived] == 'true'
      @scripts = Script.includes(:created_by, :updated_by).archived.order("updated_at desc").page params[:page]
    else
      @scripts = Script.includes(:created_by, :updated_by).active.order("updated_at desc").page params[:page]
    end
  end

  # GET /scripts/wrapped/guid.sh
  def wrapped_sh
    script = Script.where(guid: params[:guid]).first
    if script
      render text: script.remote_script(root_url)
    else
      render text: "echo 'script not found'", status: 404
    end
  end

  # GET /scripts/guid.sh
  def sh
    script = Script.where(guid: params[:guid]).first
    if script
      render text: script.runnable_script(root_url)
    else
      render text: "echo 'script not found'", status: 404
    end
  end

  # GET /scripts/1
  # GET /scripts/1.json
  def show
    @script = Script.find(params[:id])
    respond_to do |format|
      format.html { render action: 'show' }
      format.json { render action: 'show', status: :show, location: @script }
    end
  end

  # GET /scripts/new
  def new
    @script = Script.new
  end

  # GET /scripts/1/edit
  def edit
  end

  # POST /scripts
  # POST /scripts.json
  def create
    @script = Script.new(script_params.merge(created_by: current_user, updated_by: current_user))
    add_attachments
    update_hooks

    respond_to do |format|
      if @script.save
        format.html { redirect_to @script, notice: 'Script was successfully created.' }
        format.json { render action: 'show', status: :created, location: @script }
      else
        format.html { render action: 'new' }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /scripts/1
  # PATCH/PUT /scripts/1.json
  def update
    add_attachments
    Attachment.delete params[:delete_attachments] if params[:delete_attachments]

    update_hooks

    respond_to do |format|
      if @script.update(script_params.merge(updated_by: current_user))
        format.html { redirect_to @script, notice: 'Script was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @script.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scripts/1
  # DELETE /scripts/1.json
  def destroy
    @script.destroy
    respond_to do |format|
      format.html { redirect_to scripts_url }
      format.json { head :no_content }
    end
  end

  def archive
    @script.archived = true
    @script.save
    redirect_to script_path(params[:id]), notice: "Script was successfully archived."
  end

  def unarchive
    @script.archived = false
    @script.save
    redirect_to script_path(params[:id]), notice: "Script was successfully unarchived."
  end

  def grep
    render json: @script.grep_logs(params[:keyword])
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_script
      @script = Script.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def script_params
      params.require(:script).permit(:name, :body, :archived)
    end

    def attachment_params
      params.permit(attachments: [:upload])
    end

    def add_attachments
      (attachment_params[:attachments] || []).each do |attachment|
        @script.attachments << Attachment.new(attachment)
      end
    end

    def update_hooks
      @script.hooks.each do |hook|
        hook.destroy
      end
      if params[:hooks]
        params[:hooks].each do |hook|
          next if hook[:url].blank? or hook[:delete]
          @script.hooks << Hook.new(url: hook[:url])
        end
      end
    end
end
