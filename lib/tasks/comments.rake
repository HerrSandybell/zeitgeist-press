namespace :comments do
  desc "Destroy all comments from the database"
  task clear: :environment do
    count = Comment.count
    Comment.delete_all
    puts "Deleted #{count} comment(s)."
  end
end
