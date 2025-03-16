import { Box, Typography, Button, Stack } from '@mui/material';

export default function Hero() {
  return (
    <Box 
      component="section" 
      sx={{
        py: 8,
        textAlign: 'center',
        minHeight: '80vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }}
    >
      <Stack spacing={4} alignItems="center">
        <Typography variant="h1" component="h1" 
          sx={{ 
            fontSize: { xs: '2.5rem', md: '4rem' },
            fontWeight: 'bold'
          }}
        >
          한국어를 배우는 가장 쉬운 방법
        </Typography>
        <Typography variant="h5" color="text.secondary" sx={{ maxWidth: '800px' }}>
          전문 선생님들과 함께하는 맞춤형 한국어 학습으로
          당신의 한국어 실력을 향상시켜보세요
        </Typography>
        <Button variant="contained" size="large" sx={{ borderRadius: '28px', px: 4 }}>
          무료 체험 시작하기
        </Button>
      </Stack>
    </Box>
  );
} 