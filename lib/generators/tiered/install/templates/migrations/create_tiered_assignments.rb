# frozen_string_literal: true

class CreateTieredAssignments < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :tiered_assignments<% if uuid? %>, id: :uuid<% end %> do |t|
      t.references :plan_owner, polymorphic: true, null: false, index: false<% if uuid? %>, type: :uuid<% end %>
      t.string :plan_key, null: false
      t.string :source, null: false
      t.timestamps
    end

    add_index :tiered_assignments, %i[plan_owner_type plan_owner_id],
              unique: true, name: "idx_tiered_assignments_on_plan_owner"
    add_index :tiered_assignments, :plan_key
  end
end
