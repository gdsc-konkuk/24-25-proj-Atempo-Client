import { Box, Typography, Card, CardContent, Avatar, Grid } from '@mui/material';

const testimonials = [
  {
    name: 'Sarah Johnson',
    country: '미국',
    comment: '선생님들이 너무 친절하시고 수업이 재미있어요!',
    avatar: 'https://placehold.co/80x80'
  },
  {
    name: 'Liu Wei',
    country: '중국',
    comment: '체계적인 커리큘럼 덕분에 빠르게 실력이 늘고 있어요.',
    avatar: 'https://placehold.co/80x80'
  },
  {
    name: 'Tanaka Yuki',
    country: '일본',
    comment: '한국 드라마를 자막 없이 볼 수 있게 되었어요!',
    avatar: 'https://placehold.co/80x80'
  }
];

export default function Testimonials() {
  return (
    <Box component="section" sx={{ py: 8 }}>
      <Typography variant="h2" textAlign="center" mb={6}>
        수강생 후기
      </Typography>
      <Grid container spacing={4}>
        {testimonials.map((testimonial, index) => (
          <Grid item xs={12} md={4} key={index}>
            <Card sx={{ height: '100%' }}>
              <CardContent sx={{ textAlign: 'center' }}>
                <Avatar
                  src={testimonial.avatar}
                  sx={{ width: 80, height: 80, mx: 'auto', mb: 2 }}
                />
                <Typography variant="h6" gutterBottom>
                  {testimonial.name}
                </Typography>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  {testimonial.country}
                </Typography>
                <Typography variant="body1" sx={{ mt: 2 }}>
                  "{testimonial.comment}"
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
} 