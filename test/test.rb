require 'minitest/autorun'
require 'yaml-file-db'

class Test < Minitest::Test
  SOURCE = __dir__ + "/fixtures/database"
  SCHEMAS = __dir__ + "/fixtures/schemas"

  def test_db
    db = YDB::Database.new(SOURCE, SCHEMAS).build

    assert_equal db.errors, []

    user_1 = db.users["user-1"]
    assert_equal "user-1", user_1.id
    assert_equal "User 1", user_1.name
    assert_equal [], user_1.posts

    user_2 = db.users["user-2"]
    assert_equal "user-2", user_2.id
    assert_equal "User 2", user_2.name
    assert_equal [Post, Post], user_2.posts.map(&:class)

    user_3 = db.users["user-3"]
    assert_equal "user-3", user_3.id
    assert_equal "User 3", user_3.name
    assert_equal [Post], user_3.posts.map(&:class)

    post_1 = db.posts["post-1"]
    assert_equal "post-1", post_1.id
    assert_equal "Content 1", post_1.content
    assert_equal [Comment], post_1.comments.map(&:class)

    comment_1 = db.comments["comment-1"]
    assert_equal "comment-1", comment_1.id
    assert_equal "text 1", comment_1.text
    assert_equal "User 3", comment_1.user.name
    assert_equal "post-1", comment_1.post.id

    assert_equal "text 2", user_3.posts.first.comments.first.text
    assert_equal "User 2", comment_1.post.user.name
  end
end
