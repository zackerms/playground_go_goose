-- +goose Up
ALTER TABLE posts
DROP FOREIGN KEY fk_posts_user;

-- +goose Down
-- ロールバックでは外部キー制約を再作成
ALTER TABLE posts
ADD CONSTRAINT fk_posts_user
FOREIGN KEY (user_id) REFERENCES users(id) 
ON DELETE CASCADE ON UPDATE CASCADE;
