# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Admin::Roles::UsersController < ApplicationController
  def index
    @role_name = params[:role_id]
    @users = User.joins(:roles).where(roles: { name: params[:role_id] }).order(:login).uniq
  end
end
