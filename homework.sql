-- Таблица фильмов

create table movies (
    id serial primary key,
    title varchar(255) not null,
    releaseDate date not null,
    genre varchar(50) not null,
    rating decimal(2, 1) not null,
    description text not null
);

-- Таблица людей (актеры, режиссеры и т.д.)

create table people (
    id serial primary key,
    name varchar(255) not null,
    role varchar(50) not null
);

-- Таблица связи фильмов и людей

create table "MoviePeople" (
    id serial primary key,
    "movieID" int references movies(id) on delete cascade,
    "peopleID" int references people(id) on delete cascade
);

-- Таблица пользователей

create table users (
    id serial primary key,
    username varchar(50) not null unique,
    email varchar(255) not null unique,
    password varchar(255) not null
);

-- Таблица рецензий

create table reviews (
    id serial primary key,
    "movieID" int references movies(id) on delete cascade,
    "userID" int references users(id) on delete cascade,
    rating decimal(2, 1),
    reviewText text,
    reviewDate date
);

-- Таблица новостей

create table news (
    id serial primary key,
    title varchar(255) not null,
    content text not null,
    author varchar(255) not null,
    publishDate date not null
);

-- Заполнение таблицы фильмов
INSERT INTO Movies (Title, ReleaseDate, Genre, Rating, Description) VALUES
('Inception', '2010-07-16', 'Sci-Fi', 8.8, 'A thief who steals corporate secrets through the use of dream-sharing technology.'),
('The Matrix', '1999-03-31', 'Action', 8.7, 'A computer hacker learns from mysterious rebels about the true nature of his reality.');

-- Заполнение таблицы людей

insert into people (name, role) values
('Leonardo DiCaprio', 'Actor'),
('Christopher Nolan', 'Director'),
('Keanu Reeves', 'Actor'),
('Lana Wachowski', 'Director');

-- Заполнение таблицы связей фильмов и людей

insert into "MoviePeople" ("movieID", "peopleID") values
(1, 1),
(1, 2),
(2, 3),
(2, 4);

-- Заполнение таблицы пользователей

insert into users (username, email, password) values
('user1', 'user1@example.com', 'password1'),
('user2', 'user2@example.com', 'password2');

-- Заполнение таблицы рецензий

insert into reviews ("movieID", "userID", rating, reviewtext, reviewdate) values
(1, 1, 9.0, 'Amazing movie with a mind-bending plot!', '2023-07-01'),
(2, 2, 8.5, 'A groundbreaking film that redefined the sci-fi genre.', '2023-07-02');

-- Заполнение таблицы новостей

insert into news (title, content, author, publishdate) values
('New Sci-Fi Movies to Watch', 'A list of upcoming sci-fi movies to watch out for.', 'Editor', '2023-07-01');

-- Получение списка всех фильмов с деталями
select * from movies

-- Поиск фильмов по жанру и дате выпуска
select * from movies where genre = 'Sci-Fi' and releasedate >= '2000-01-01'

-- Получение списка актеров и их ролей в конкретных фильмах
select p.name, p.role
from people p
join "MoviePeople" mp on mp."peopleID" = p.id
where mp."movieID" = 1;

-- Получение списка рецензий и оценок для конкретного фильма
select u.username, r.rating, r.reviewtext, r.reviewdate
from reviews r
join users u on u.id = r."userID"
where r."movieID" = 1;

-- Добавление нового фильма
insert into movies (title, releasedate, genre, rating, description) values
('Interstellar', '2014-11-07', 'Sci-Fi', 8.6, 'A team of explorers travel through a wormhole in space in an attempt to ensure humanity survival.');

-- Обновление информации о фильме
update movies
set rating = 9.0
where id = 1;

-- Удаление фильма
delete from movies
where id = 2;

-- Добавление рецензии
insert into reviews ("movieID", "userID", rating, reviewtext, reviewdate) values
(1, 2, 8.0, 'Great film, very thought-provoking!', '2023-07-03');

-- Удаление рецензии
delete from reviews where id = 1;

-- Представление для упрощения получения информации о фильмах
create view "MovieDetails" as
select m.id, m.title, m.releasedate, m.genre, m.rating, m.description, p.name as "Actor", p.role
from movies m
join "MoviePeople" mp on mp."movieID" = m.id
join people p on mp."peopleID" = p.id;

-- Представление для упрощения получения рецензий
create view "ReviewDetails" as
select r.id, r."movieID", m.title, u.username, r.rating, r.reviewtext, r.reviewdate
from reviews r
join movies m on m.id = r."movieID"
join users u on u.id = r."userID";

-- Создание хранимой процедуры для добавления нового фильма вместе с актерами и режиссерами
create or replace procedure "AddMovieWithPeople" (
    in "movieTitle" varchar(255),
    in "releaseDate" date,
    in genre varchar(50),
    in rating decimal(2, 1),
    in description text,
    in actors jsonb
)
language plpgsql
as $$
declare
    "newMovieID" int;
    actor jsonb;
    "actorName" varchar(255);
    "actorRole" varchar(255);
    "personID" int;
begin
    -- добавляем новый фильм
    insert into movies (title, releasedate, genre, rating, description) values
    ("movieTitle", "releaseDate", genre, rating, description)
    returning id into "newMovieID";

    -- Обрабатываем JSONB массив актеров и режиссеров
    for actor in select * from jsonb_array_elements(actors)
    loop
        "actorName" := actor ->>'Name';
        "actorRole" := actor ->>'Role';

        -- Проверяем, существует ли уже этот человек в таблице People
        select id into "personID" from people where name="actorName" and role="actorRole" limit 1;

        -- Если человек не существует, добавляем его
        if "personID" is null then
            insert into people (name, role) values ("actorName", "actorRole")
            returning id into "personID";
        end if;

        -- Добавляем запись в MoviePeople
        insert into "MoviePeople" ("movieID", "peopleID") values ("newMovieID", "personID");
    end loop;
end;
$$

-- Дополнительные задания
-- Таблица избранных фильмов
create table "FavoriteMovies" (
    id serial primary key,
    "userID" int references users(id) on delete cascade,
    "movieID" int references movies(id) on delete cascade
);

-- Таблица комментариев
create table "ReviewComments" (
    id serial primary key,
    "reviewID" int references reviews(id) on delete cascade,
    "userID" int references users(id) on delete cascade,
    "commentText" text,
    "commentDate" date
);
