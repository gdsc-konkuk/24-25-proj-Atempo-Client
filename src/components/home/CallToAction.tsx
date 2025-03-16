import { Box, Typography, Button, Paper } from '@mui/material';

export default function CallToAction() {
  return (
    <Paper 
      component="section"
      sx={{
        py: 8,
        px: 4,
        textAlign: 'center',
        bgcolor: 'primary.light',
        my: 8,
        borderRadius: 4
      }}
    >
      <Typography variant="h3" gutterBottom>
        지금 시작하세요
      </Typography>
      <Typography variant="h6" color="text.secondary" sx={{ mb: 4 }}>
        첫 달 수업 50% 할인 이벤트 진행중
      </Typography>
      <Button 
        variant="contained" 
        size="large"
        sx={{ 
          borderRadius: '28px',
          px: 4,
          py: 1.5,
          fontSize: '1.1rem'
        }}
      >
        무료 체험 신청하기
      </Button>
    </Paper>
  );
} 