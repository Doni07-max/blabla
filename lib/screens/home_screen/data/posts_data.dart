import 'package:android_dev/screens/home_screen/models/comment_model.dart';
import 'package:android_dev/screens/home_screen/models/post_model.dart';
import 'package:android_dev/screens/home_screen/models/story_model.dart';

final List<StoryModel> storiesData = [
  StoryModel(username: 'aida_k', avatarUrl: 'https://i.pravatar.cc/150?img=1'),
  StoryModel(username: 'bekzat', avatarUrl: 'https://i.pravatar.cc/150?img=3'),
  StoryModel(username: 'nurlan_99', avatarUrl: 'https://i.pravatar.cc/150?img=5'),
  StoryModel(username: 'aliya.m', avatarUrl: 'https://i.pravatar.cc/150?img=9'),
  StoryModel(username: 'timur', avatarUrl: 'https://i.pravatar.cc/150?img=11'),
  StoryModel(username: 'dana_s', avatarUrl: 'https://i.pravatar.cc/150?img=16'),
  StoryModel(username: 'erlan', avatarUrl: 'https://i.pravatar.cc/150?img=12'),
  StoryModel(username: 'kamila', avatarUrl: 'https://i.pravatar.cc/150?img=20'),
  StoryModel(username: 'azamat', avatarUrl: 'https://i.pravatar.cc/150?img=13'),
  StoryModel(username: 'zarina', avatarUrl: 'https://i.pravatar.cc/150?img=25'),
];

final List<PostModel> postsData = [
  PostModel(
    username: 'aida_k',
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
    imageUrl: 'https://picsum.photos/id/10/600/400',
    description: 'Утро в горах, воздух просто огонь',
    likeCount: 120,
    comments: [
      CommentModel(username: 'bekzat', avatarUrl: 'https://i.pravatar.cc/150?img=3', text: 'Очень красиво!'),
      CommentModel(username: 'dana_s', avatarUrl: 'https://i.pravatar.cc/150?img=16', text: 'Где это?'),
    ],
  ),
  PostModel(
    username: 'bekzat',
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
    imageUrl: 'https://picsum.photos/id/20/600/400',
    description: 'Рабочее место на сегодня',
    likeCount: 45,
    comments: [
      CommentModel(username: 'timur', avatarUrl: 'https://i.pravatar.cc/150?img=11', text: 'Уютно'),
    ],
  ),
  PostModel(
    username: 'nurlan_99',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    imageUrl: 'https://picsum.photos/id/29/600/400',
    description: 'Наконец-то добрался до вершины',
    likeCount: 230,
    comments: [
      CommentModel(username: 'aida_k', avatarUrl: 'https://i.pravatar.cc/150?img=1', text: 'Молодец!'),
      CommentModel(username: 'erlan', avatarUrl: 'https://i.pravatar.cc/150?img=12', text: 'В следующий раз зови меня'),
      CommentModel(username: 'kamila', avatarUrl: 'https://i.pravatar.cc/150?img=20', text: 'Вау'),
    ],
  ),
  PostModel(
    username: 'aliya.m',
    avatarUrl: 'https://i.pravatar.cc/150?img=9',
    imageUrl: 'https://picsum.photos/id/42/600/400',
    description: 'Кофе и хорошая книга',
    likeCount: 87,
    comments: [
      CommentModel(username: 'zarina', avatarUrl: 'https://i.pravatar.cc/150?img=25', text: 'Что за книга?'),
    ],
  ),
  PostModel(
    username: 'timur',
    avatarUrl: 'https://i.pravatar.cc/150?img=11',
    imageUrl: 'https://picsum.photos/id/57/600/400',
    description: 'Вечерний город',
    likeCount: 64,
    comments: [
      CommentModel(username: 'azamat', avatarUrl: 'https://i.pravatar.cc/150?img=13', text: 'Классный кадр'),
      CommentModel(username: 'bekzat', avatarUrl: 'https://i.pravatar.cc/150?img=3', text: 'Огонь'),
    ],
  ),
  PostModel(
    username: 'dana_s',
    avatarUrl: 'https://i.pravatar.cc/150?img=16',
    imageUrl: 'https://picsum.photos/id/64/600/400',
    description: 'Новая прическа, как вам?',
    likeCount: 312,
    comments: [
      CommentModel(username: 'aliya.m', avatarUrl: 'https://i.pravatar.cc/150?img=9', text: 'Тебе очень идет'),
      CommentModel(username: 'kamila', avatarUrl: 'https://i.pravatar.cc/150?img=20', text: 'Красотка'),
    ],
  ),
  PostModel(
    username: 'erlan',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    imageUrl: 'https://picsum.photos/id/76/600/400',
    description: 'Выходные на природе',
    likeCount: 58,
    comments: [
      CommentModel(username: 'nurlan_99', avatarUrl: 'https://i.pravatar.cc/150?img=5', text: 'Завидую'),
    ],
  ),
  PostModel(
    username: 'kamila',
    avatarUrl: 'https://i.pravatar.cc/150?img=20',
    imageUrl: 'https://picsum.photos/id/96/600/400',
    description: 'Закат сегодня был нереальный',
    likeCount: 190,
    comments: [
      CommentModel(username: 'dana_s', avatarUrl: 'https://i.pravatar.cc/150?img=16', text: 'Цвета супер'),
      CommentModel(username: 'timur', avatarUrl: 'https://i.pravatar.cc/150?img=11', text: 'На какой телефон снимала?'),
    ],
  ),
  PostModel(
    username: 'azamat',
    avatarUrl: 'https://i.pravatar.cc/150?img=13',
    imageUrl: 'https://picsum.photos/id/111/600/400',
    description: 'Старая машина деда',
    likeCount: 143,
    comments: [
      CommentModel(username: 'erlan', avatarUrl: 'https://i.pravatar.cc/150?img=12', text: 'Легенда'),
    ],
  ),
  PostModel(
    username: 'zarina',
    avatarUrl: 'https://i.pravatar.cc/150?img=25',
    imageUrl: 'https://picsum.photos/id/119/600/400',
    description: 'Учеба учеба учеба',
    likeCount: 33,
    comments: [
      CommentModel(username: 'aliya.m', avatarUrl: 'https://i.pravatar.cc/150?img=9', text: 'Держись!'),
      CommentModel(username: 'bekzat', avatarUrl: 'https://i.pravatar.cc/150?img=3', text: 'Сессия скоро'),
    ],
  ),
  PostModel(
    username: 'aida_k',
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
    imageUrl: 'https://picsum.photos/id/137/600/400',
    description: 'Прогулка у озера',
    likeCount: 76,
    comments: [
      CommentModel(username: 'zarina', avatarUrl: 'https://i.pravatar.cc/150?img=25', text: 'Иссык-Куль?'),
    ],
  ),
  PostModel(
    username: 'bekzat',
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
    imageUrl: 'https://picsum.photos/id/152/600/400',
    description: 'Цветы для мамы',
    likeCount: 210,
    comments: [
      CommentModel(username: 'kamila', avatarUrl: 'https://i.pravatar.cc/150?img=20', text: 'Как мило'),
      CommentModel(username: 'aida_k', avatarUrl: 'https://i.pravatar.cc/150?img=1', text: 'Красивый букет'),
    ],
  ),
  PostModel(
    username: 'nurlan_99',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    imageUrl: 'https://picsum.photos/id/164/600/400',
    description: 'Дорога домой',
    likeCount: 49,
    comments: [
      CommentModel(username: 'azamat', avatarUrl: 'https://i.pravatar.cc/150?img=13', text: 'Хорошей дороги'),
    ],
  ),
  PostModel(
    username: 'aliya.m',
    avatarUrl: 'https://i.pravatar.cc/150?img=9',
    imageUrl: 'https://picsum.photos/id/175/600/400',
    description: 'Часы которые подарили на др',
    likeCount: 98,
    comments: [
      CommentModel(username: 'dana_s', avatarUrl: 'https://i.pravatar.cc/150?img=16', text: 'С днем рождения!'),
      CommentModel(username: 'erlan', avatarUrl: 'https://i.pravatar.cc/150?img=12', text: 'Стильные'),
    ],
  ),
  PostModel(
    username: 'timur',
    avatarUrl: 'https://i.pravatar.cc/150?img=11',
    imageUrl: 'https://picsum.photos/id/180/600/400',
    description: 'Пишу код до ночи',
    likeCount: 27,
    comments: [
      CommentModel(username: 'nurlan_99', avatarUrl: 'https://i.pravatar.cc/150?img=5', text: 'Flutter?'),
    ],
  ),
  PostModel(
    username: 'dana_s',
    avatarUrl: 'https://i.pravatar.cc/150?img=16',
    imageUrl: 'https://picsum.photos/id/200/600/400',
    description: 'Встретила корову в горах',
    likeCount: 165,
    comments: [
      CommentModel(username: 'timur', avatarUrl: 'https://i.pravatar.cc/150?img=11', text: 'Ахаха'),
      CommentModel(username: 'zarina', avatarUrl: 'https://i.pravatar.cc/150?img=25', text: 'Милашка'),
    ],
  ),
  PostModel(
    username: 'erlan',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
    imageUrl: 'https://picsum.photos/id/219/600/400',
    description: 'Тигр в зоопарке',
    likeCount: 72,
    comments: [
      CommentModel(username: 'kamila', avatarUrl: 'https://i.pravatar.cc/150?img=20', text: 'Какой большой'),
    ],
  ),
  PostModel(
    username: 'kamila',
    avatarUrl: 'https://i.pravatar.cc/150?img=20',
    imageUrl: 'https://picsum.photos/id/225/600/400',
    description: 'Чай с мятой',
    likeCount: 54,
    comments: [
      CommentModel(username: 'aliya.m', avatarUrl: 'https://i.pravatar.cc/150?img=9', text: 'Хочу тоже'),
    ],
  ),
  PostModel(
    username: 'azamat',
    avatarUrl: 'https://i.pravatar.cc/150?img=13',
    imageUrl: 'https://picsum.photos/id/237/600/400',
    description: 'Мой пес Рекс',
    likeCount: 401,
    comments: [
      CommentModel(username: 'aida_k', avatarUrl: 'https://i.pravatar.cc/150?img=1', text: 'Какой хороший'),
      CommentModel(username: 'dana_s', avatarUrl: 'https://i.pravatar.cc/150?img=16', text: 'Погладить бы'),
      CommentModel(username: 'bekzat', avatarUrl: 'https://i.pravatar.cc/150?img=3', text: 'Лучший'),
    ],
  ),
  PostModel(
    username: 'zarina',
    avatarUrl: 'https://i.pravatar.cc/150?img=25',
    imageUrl: 'https://picsum.photos/id/250/600/400',
    description: 'Новая камера, первые кадры',
    likeCount: 118,
    comments: [
      CommentModel(username: 'azamat', avatarUrl: 'https://i.pravatar.cc/150?img=13', text: 'Какая модель?'),
    ],
  ),
];
