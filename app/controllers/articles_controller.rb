class ArticlesController < ApplicationController
  before_filter :find_article, :only => [:show, :edit, :update]

    def index
        respond_to do |format|
            format.html {
                @articles = Kaminari.paginate_array(Article.non_flagged_articles.sort_by! { |article| article.score }).page(params[:page]).per(20)
            }
            format.json {
                render :json => Article.non_flagged_articles.sort_by! { |article| article.score }
            }
        end
    end
    
    def show
        @comment = @article.comments.new
    end

    def new
        @article = Article.new
        unless signed_in?
            flash[:error] = 'Please sign in to submit an article'
            redirect_to new_user_session_path
        end
    end

    def create
        @article = Article.new(params[:article])
        @article[:user_id] = current_user.id
        if @article.save
            flash[:success] = "Thanks for submitting an article"
            @article.votes.create(:user_id => current_user.id, :value => 1)
            redirect_to root_path
        else
            flash[:error] = "Invalid Submission"
            render 'new'
        end
    end

    def edit
        if current_user != @article.user
            flash[:error] = "That article doesn't belong to you!"
            redirect_to root_path
        end
        if @article.too_late_to_edit?
            flash[:error] = "Can't edit after 15 minutes"
            redirect_to root_path
        end
    end

  def update
    if current_user == @article.user && @article.update_attributes(params[:article])
      flash[:success] = 'Article successfully updated'
      redirect_to user_path(current_user)
    else
      flash[:error] = "Invalid Edit"
      redirect_to edit_article_path(@article)
    end
  end

  private

  def find_article
    @article = Article.find_by_id(params[:id])
  end
end
