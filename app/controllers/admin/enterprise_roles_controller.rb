# frozen_string_literal: true

module Admin
  class EnterpriseRolesController < Admin::ResourceController
    def index
      @enterprise_roles, @users, @all_enterprises = Admin::EnterpriseRolesQuery.query
    end

    def create
      @enterprise_role = EnterpriseRole.new enterprise_role_params

      status = @enterprise_role.save ? :ok : :unprocessable_entity

      respond_to do |format|
        format.turbo_stream { render :create, status: }
        format.html do
          flash[:error] = @enterprise_role.errors.full_messages.to_sentence if status != :ok
          redirect_to admin_enterprise_roles_path
        end
      end
    end

    def destroy
      @enterprise_role = EnterpriseRole.find params[:id]
      @enterprise_role.destroy
      respond_with do |format|
        format.turbo_stream { render :destroy }
        format.html { render body: nil }
      end
    end

    private

    def enterprise_role_params
      params.require(:enterprise_role).permit(:user_id, :enterprise_id)
    end
  end
end
