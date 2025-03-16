import { Card, CardContent, Typography, Box, Button, LinearProgress } from '@mui/material';
import SchoolIcon from '@mui/icons-material/School';

export default function RecentLearning() {
  return (
    <Card sx={{ mb: 4 }}>
      <CardContent>
        <Typography variant="h6" sx={{ mb: 2 }}>
          최근 학습
        </Typography>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <SchoolIcon sx={{ fontSize: 40, mr: 2 }} />
          <Box>
            <Typography variant="subtitle1">학교 생활</Typography>
            <Typography variant="body2" color="text.secondary">
              10개 중 5개 완료
            </Typography>
          </Box>
        </Box>
        <LinearProgress 
          variant="determinate" 
          value={50} 
          sx={{ 
            height: 8,
            borderRadius: 4,
            bgcolor: '#f0f0f0',
            '& .MuiLinearProgress-bar': {
              bgcolor: '#FF66C0'
            }
          }} 
        />
        <Button 
          variant="contained" 
          fullWidth 
          sx={{ mt: 2, bgcolor: '#FF66C0' }}
        >
          계속 학습하기
        </Button>
      </CardContent>
    </Card>
  );
} 