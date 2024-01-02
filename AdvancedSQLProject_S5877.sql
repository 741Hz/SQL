use ig_clone;
-- 1 How many times does the average user post?
-- We calculated the average number of posts made by users on the platform. 
-- I use subquery to acheive this task. Here inner query gets the count of posts by the users and passes that count to outer query which takes the avg of the count. Which gives the average of the posts
SELECT 
    AVG(post_count) AS average_posts
FROM
    (SELECT 
        user_id, COUNT(*) AS post_count
    FROM
        photos
    GROUP BY user_id) AS user_posts;

-- 2 Find the top 5 most used hashtags
-- We identified the top 5 most used hashtags, allowing us to understand trending topics on the platform.

SELECT t.tag_name, COUNT(pt.tag_id) AS tag_count
FROM tags t
LEFT JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.tag_name
ORDER BY tag_count DESC
LIMIT 5;

-- 3 Find users who have liked every single photo on the site.
-- To find users who have liked every single photo on the site. This information is valuable for identifying highly engaged users.
SELECT 
    u.id, u.username
FROM
    users u
WHERE
    NOT EXISTS( SELECT 
            p.id
        FROM
            photos p
        WHERE
            NOT EXISTS( SELECT 
                    l.photo_id
                FROM
                    likes l
                WHERE
                    l.user_id = u.id AND l.photo_id = p.id));

-- 4 Retrieve a list of users alONg WITH their usernames and the RANK of their acCOUNT creatiON, ORDERed BY the creatiON date in AScending ORDER.
-- We ranked users based on the creation date of their accounts. This helps us understand the growth of our user base over time.
SELECT username,created_at,
RANK() OVER(ORDER BY created_at)AS userRank
 FROM users;

-- 5 List the comments made ON photos WITH their comment texts, photo URLs, and usernames of users who posted the comments. Include the comment COUNT for each photo
-- We listed comments made on photos along with usernames, comment texts, and the count of comments for each photo. This gives us an idea of user engagement with specific photos.
SELECT u.username,c.comment_text,p.image_url,
COUNT(c.comment_text) OVER(partitiON BY p.image_url) CommentCount
FROM users u 
INNER JOIN photos p 
ON u.id=p.user_id
INNER JOIN comments c
ON p.id=c.photo_id;

--  6 For each tag, show the tag name and the number of photos ASsociated WITH that tag. Rank the tags BY the number of photos in descending ORDER.
--  Tags are ranked by the number of photos, helping us identify popular topics.
 
SELECT tagname,num_photos, RANK() OVER(ORDER BY num_photos desc) AS photoRank 
FROM (
SELECT t.tag_name tagname, COUNT(pt.photo_id) num_photos
FROM tags t
INNER JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.tag_name
) AS tagphotos;


-- 7 List the usernames of users who have posted photos alONg WITH the COUNT of photos they have posted. Rank them BY the number of photos in descending ORDER.
-- This helps us identify top contributors.
SELECT username, num_photos, RANK() OVER(ORDER BY num_photos desc) AS photoRank 
FROM
(SELECT u.username username,COUNT(p.id) num_photos
FROM users u 
INNER JOIN photos p 
ON u.id=p.user_id
group BY u.username) AS postedPhotos;

 -- 8 Display the username of each user alONg WITH the creatiON date of their first posted photo and the creatiON date of their next posted photo.
 -- . This information is useful for understanding user posting patterns.
 
WITH PhotosCTE AS (
    SELECT u.id AS user_id, 
           u.username,
           p.id AS photo_id,
           p.created_at,
           LEAD(p.created_at) OVER (PARTITION BY u.id ORDER BY p.created_at) AS next_photo_date
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
)
SELECT username, 
       MIN(created_at) AS first_post_date, 
       MIN(next_photo_date) AS next_post_date
FROM PhotosCTE
WHERE photo_id IS NOT NULL
GROUP BY username;


-- 9 For each comment, show the comment text, the username of the commenter, and the comment text of the previous comment made ON the same photo.
-- This helps us analyze conversation flows.

WITH CommentsCTE AS (
    SELECT 
        c.id AS comment_id,
        c.comment_text,
        u.username AS commenter_username,
        p.id photo_id,
        LAG(c.comment_text) OVER (PARTITION BY c.photo_id ORDER BY c.created_at) AS previous_comment_text
    FROM 
        comments c
    JOIN 
        users u ON c.user_id = u.id
        INNER JOIN photos p 
        ON c.photo_id=p.id
)

SELECT 
    comment_id,
    comment_text,
    commenter_username,
    previous_comment_text,
    photo_id
FROM 
    CommentsCTE;


-- 10  Show the username of each user alONg WITH the number of photos they have posted and the number of photos posted BY the user before them and after them, bASed ON the creatiON date.
  -- This gives us insights into user activity patterns over time.
SELECT 
    username,
    createdDate,
    num_photos,
    LAG(num_photos) OVER (PARTITION BY username ORDER BY createdDate) AS photos_before,
    LEAD(num_photos) OVER (PARTITION BY username ORDER BY createdDate) AS photos_after
FROM (
    SELECT 
        u.username,
        p.created_at AS createdDate,
        COUNT(*) OVER (PARTITION BY u.username ORDER BY p.created_at) AS num_photos
    FROM 
        users u
    JOIN 
        photos p ON u.id = p.user_id
) AS photoByCreation;


