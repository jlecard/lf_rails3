Factory.sequence :coll_group_name do |n|
  "collection_group_#{n}"
end

Factory.sequence :coll_group_full_name do |n|
  "full_name_#{n}"
end

Factory.define :collection_group_seq, :class=>:collection_group do |c|
  c.name {"#{Factory.next(:coll_group_name)}"}
end

Factory.define :collection_group_with_members_seq, :class=>:collection_group do |c|
  c.name {"#{Factory.next(:coll_group_name)}"}
  c.collections {|collections| [collections.association(:collection_seq),collections.association(:collection_seq)]}
end

Factory.define :collection_group_seq_with_full_name, :class=>:collection_group do |c|
  c.name {"#{Factory.next(:coll_group_name)}"}
  c.alt_name {"#{Factory.next(:coll_group_full_name)}"}
end


