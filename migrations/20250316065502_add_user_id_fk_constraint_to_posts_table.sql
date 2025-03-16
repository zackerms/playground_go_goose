-- +goose Up
ALTER TABLE posts
ADD CONSTRAINT fk_posts_user 
FOREIGN KEY (user_id) REFERENCES users(id) 
ON DELETE CASCADE ON UPDATE CASCADE;

-- +goose Down
ALTER TABLE posts
DROP FOREIGN KEY fk_posts_user;