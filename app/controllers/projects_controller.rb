class ProjectsController < ApplicationController
  before_filter :require_user, only: [:new, :create, :validate, :vote_confirm, :vote, :unvote]

  def index
    load_index
  end

  def bucket
    @bucket = params[:bucket]
    load_bucket(@bucket)

    if params[:partial]
      render partial: "projects/bucket", locals: {
        bucket: @bucket,
        projects: @projects
      }
    else
      render
    end
  end

  def vote_confirm
    load_project
  end

  def vote
    load_project

    current_user.vote(@project)

    respond_to do |format|
      format.html do
        flash[:message] = "Your vote has been counted."

        # TODO: redirect to the project detail page instead
        redirect_to "/"
      end
      format.json do
        render json: @project, root: "project"
      end
    end

  end

  def unvote
    load_project

    current_user.unvote(@project)

    respond_to do |format|
      format.html do
        flash[:message] = "Your vote has been removed."

        # TODO: redirect to the project detail page instead
        redirect_to "/"
      end
      format.json do
        render json: @project, root: "project"
      end
    end

  end

  def new

  end

  def create
    form = ProjectForm.new(params)
    if form.valid?
      project = Project.new(form.attributes)
      project.user = current_user
      project.save!
      current_user.vote(project)
      redirect_to "/"
    else
      @errors = form.errors
      render :new
    end
  end

  def feedback
    load_project
    load_feedback

    if params[:partial]
      render partial: "projects/feedback", project: @project, feedback: @feedback
    else
      @show_feedback_panel = true
      load_index
      render :index
    end
  end

  def set_feedback
    load_feedback

    # TODO
  end

  def validate_project
    # TODO: validate project fields (name, url, description), via ajax
  end

  protected
  def load_index
    @bucket = Project.bucket(current_now)
    load_bucket(@bucket)
  end

  def load_project
    @project = Project.where(id: params[:id]).first
  end

  def load_feedback
    @feedback = Feedback.where({
      user_id: current_user.id,
      project_id: @project.id
    }).first
  end

  def load_bucket(bucket)
    @projects = Project.for_bucket(bucket).includes(:user).to_a
    if current_user.present?
      @vote_ids = current_user.match_votes(@projects.map(&:id))
    end
  end
end
