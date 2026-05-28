# frozen_string_literal: true

class CreateTieredUsages < ActiveRecord::Migration[<%= ActiveRecord::Migration.current_version %>]
  def change
    create_table :tiered_usages<% if uuid? %>, id: :uuid<% end %> do |t|
      t.references :plan_owner, polymorphic: true, null: false, index: false<% if uuid? %>, type: :uuid<% end %>
      t.string :quota_key, null: false
      t.datetime :period_start, null: false
      t.datetime :period_end
      t.bigint :used, default: 0
      t.datetime :last_used_at
      t.timestamps
    end

    add_index :tiered_usages,
              [:plan_owner_type, :plan_owner_id, :quota_key, :period_start],
              unique: true, name: "idx_tiered_usages_unique"
    add_index :tiered_usages, [:plan_owner_type, :plan_owner_id],
              name: "idx_tiered_usages_on_plan_owner"
    add_index :tiered_usages, [:period_start, :period_end]
  end
end
