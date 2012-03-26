Factory.define :admin, :class=>:user do |u|
  u.name "admin2"
  u.password "password"
  u.password_confirmation "password"
  u.email "test@test.com"
  u.administrator true
end