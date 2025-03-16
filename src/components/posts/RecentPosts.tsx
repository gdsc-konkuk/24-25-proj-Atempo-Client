'use client'

import { Card, CardContent, Typography, Box, Chip } from '@mui/material';

const posts = [
  {
    title: '오늘 퀴즈 100% 정답 맞췄어요!',
    category: '한국어마스터',
    likes: 128,
    comments: 45
  },
  {
    title: '오늘 퀴즈 100% 정답 맞췄어요!',
    category: '한국어마스터',
    likes: 128,
    comments: 45
  },
  {
    title: '오늘 퀴즈 100% 정답 맞췄어요!',
    category: '한국어마스터',
    likes: 128,
    comments: 45
  }
];

export default function RecentPosts() {
  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="h6">인기 게시글</Typography>
        <Typography 
          variant="body2" 
          sx={{ 
            color: 'primary.main',
            cursor: 'pointer'
          }}
        >
          더보기
        </Typography>
      </Box>
      {posts.map((post, index) => (
        <Card key={index} sx={{ mb: 2 }}>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
              <Chip 
                label="😊" 
                size="small" 
                sx={{ mr: 1 }}
              />
              <Typography variant="body2" color="text.secondary">
                {post.category}
              </Typography>
            </Box>
            <Typography variant="subtitle1">{post.title}</Typography>
            <Box sx={{ display: 'flex', gap: 2, mt: 1 }}>
              <Typography variant="body2" color="text.secondary">
                👍 {post.likes}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                💬 {post.comments}
              </Typography>
            </Box>
          </CardContent>
        </Card>
      ))}
    </Box>
  );
} 