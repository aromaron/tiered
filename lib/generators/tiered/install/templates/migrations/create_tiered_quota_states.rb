# frozen_string_literal: true

class CreateTieredQuotaStates < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :tiered_quota_states<% if uuid? %>, id: :uuid<% end %> do |t|
      t.references :plan_owner, polymorphic: true, null: false, index: false<% if uuid? %>, type: :uuid<% end %>
      t.string :quota_key, null: false
      t.datetime :exceeded_at
      t.datetime :blocked_at
      t.decimal :last_warning_threshold
      t.datetime :last_warning_at
      t.json :metadata
      t.timestamps
    end

    add_index :tiered_quota_states,
              [:plan_owner_type, :plan_owner_id, :quota_key],
              unique: true, name: "idx_tiered_quota_states_unique"
    add_index :tiered_quota_states, [:plan_owner_type, :plan_owner_id],
              name: "idx_tiered_quota_states_on_plan_owner"
    add_index :tiered_quota_states, :exceeded_at
  end
end
