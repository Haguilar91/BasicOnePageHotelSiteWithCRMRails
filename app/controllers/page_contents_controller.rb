class PageContentsController < ApplicationController
  before_action :set_page_content, only: %i[ show edit update destroy ]

  # GET /page_contents
  def index
    @page_contents = PageContent.all
  end

  # GET /page_contents/1
  def show
  end

  # GET /page_contents/new
  def new
    @page_content = PageContent.new
  end

  # GET /page_contents/1/edit
  def edit
  end

  # POST /page_contents
  def create
    @page_content = PageContent.new(page_content_params)

    if @page_content.save
      redirect_to @page_content, notice: "Page content was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /page_contents/1
  def update
    if @page_content.update(page_content_params)
      redirect_to @page_content, notice: "Page content was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /page_contents/1
  def destroy
    @page_content.destroy!
    redirect_to page_contents_path, notice: "Page content was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_page_content
      @page_content = PageContent.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def page_content_params
      params.expect(page_content: [ :key, :title, :content ])
    end
end
