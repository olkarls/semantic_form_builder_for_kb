ActiveRecord::Schema.define(:version => 0) do
  create_table :users, :force => true do |t|
    t.string    :name
    t.string    :email
    t.integer   :age
    t.date      :date_of_birth
    t.datetime  :registered_at
    t.boolean   :accepted_terms
    t.text      :bio
  end
end