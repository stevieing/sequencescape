#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require "test_helper"
require 'studies/workflows_controller'

# Re-raise errors caught by the controller.
class Studies::WorkflowsController; def rescue_action(e) raise e end; end

class Studies::WorkflowsControllerTest < ActionController::TestCase
  context "Studies controller" do
    setup do
      @controller = Studies::WorkflowsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @workflow = Factory :submission_workflow
      @user     = Factory :user, :login => "someone", :workflow_id => @workflow.id
      @controller.stubs(:current_user).returns(@user)
      @study  = Factory :study
    end

    should_require_login(:show)

     context "#show" do
        setup do
          @controller.stubs(:current_user).returns(@user)
          get :show, :id => @workflow.id, :study_id => @study.id
        end
        should_respond_with :success
        should_render_template :show
      end
  end
end
