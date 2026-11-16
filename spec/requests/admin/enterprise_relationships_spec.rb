# frozen_string_literal: true

RSpec.describe "/admin/enterprise_relationships" do
  let(:enterprise) { create(:supplier_enterprise, name: "Parent") }
  let(:enterprise_user) { create(:user, enterprise_limit: 1) }
  let(:child_enterprise) { create(:supplier_enterprise, name: "Child") }
  let(:turbo_stream) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    enterprise_user.enterprise_roles.build(enterprise:).save
    sign_in enterprise_user
  end

  describe "POST /admin/enterprises/" do
    it "creates a new relationshsip" do
      params = {
        enterprise_relationship: {
          parent_id: enterprise.id,
          child_id: child_enterprise.id,
          permissions_list: ["manage_products"]
        }
      }
      post(admin_enterprise_relationships_path, params:, headers: turbo_stream)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include "Parent", "Child", "manage products"

      relation = EnterpriseRelationship.where(parent: enterprise, child: child_enterprise).first
      expect(relation.permissions_list).to include("manage_products")
    end

    context "with a parent enterprise the user doesn't manage" do
      it "returns forbidden" do
        other_enterprise = create(:supplier_enterprise)
        params = {
          enterprise_relationship: {
            parent_id: other_enterprise.id,
            child_id: child_enterprise.id,
            permissions_list: ["manage_products"]
          }
        }
        post(admin_enterprise_relationships_path, params:, headers: turbo_stream)

        expect(response).to redirect_to unauthorized_path
      end
    end

    context "with an admin user" do
      let(:admin) { create(:user, admin: true) }

      before do
        sign_in admin
      end

      it "can add permission for an enterprise they don't manage" do
        other_enterprise = create(:supplier_enterprise)

        params = {
          enterprise_relationship: {
            parent_id: other_enterprise.id,
            child_id: child_enterprise.id,
            permissions_list: ["manage_products"]
          }
        }
        post(admin_enterprise_relationships_path, params:, headers: turbo_stream)

        expect(response).to have_http_status(:ok)

        relation = EnterpriseRelationship.where(parent: other_enterprise,
                                                child: child_enterprise).first
        expect(relation.permissions_list).to include("manage_products")
      end
    end

    context "when an error occurs when saving the relationship" do
      it "renders an error message" do
        params = {
          enterprise_relationship: {
            parent_id: enterprise.id,
            child_id: -99,
            permissions_list: ["manage_products"]
          }
        }

        post(admin_enterprise_relationships_path, params:, headers: turbo_stream)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include "Child must exist"
      end

      it "redirects with an error message without Turbo" do
        params = {
          enterprise_relationship: {
            parent_id: enterprise.id,
            child_id: -99,
            permissions_list: ["manage_products"]
          }
        }

        post(admin_enterprise_relationships_path, params:)

        expect(response).to redirect_to admin_enterprise_relationships_path
        expect(flash[:error]).to eq "Child must exist"
      end
    end
  end
end
