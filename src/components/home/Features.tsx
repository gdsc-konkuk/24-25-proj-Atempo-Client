import { Box, Grid, Typography, Paper } from '@mui/material';
import SchoolIcon from '@mui/icons-material/School';
import GroupsIcon from '@mui/icons-material/Groups';
import TranslateIcon from '@mui/icons-material/Translate';

const features = [
  {
    icon: <SchoolIcon sx={{ fontSize: 40 }} />,
    title: '전문 선생님',
    description: '검증된 한국어 교육 전문가들이 직접 가르칩니다'
  },
  {
    icon: <GroupsIcon sx={{ fontSize: 40 }} />,
    title: '소그룹 수업',
    description: '4-6명의 소규모 그룹으로 진행되는 맞춤형 수업'
  },
  {
    icon: <TranslateIcon sx={{ fontSize: 40 }} />,
    title: '실전 회화',
    description: '실생활에서 바로 사용할 수 있는 실용적인 한국어'
  }
];

export default function Features() {
  return (
    <Box component="section" sx={{ py: 8 }}>
      <Typography variant="h2" textAlign="center" mb={6}>
        우리의 특징
      </Typography>
      <Grid container spacing={4}>
        {features.map((feature, index) => (
          <Grid item xs={12} md={4} key={index}>
            <Paper 
              elevation={2}
              sx={{
                p: 4,
                height: '100%',
                textAlign: 'center',
                transition: 'transform 0.2s',
                '&:hover': {
                  transform: 'translateY(-8px)'
                }
              }}
            >
              {feature.icon}
              <Typography variant="h5" mt={2} mb={1}>
                {feature.title}
              </Typography>
              <Typography color="text.secondary">
                {feature.description}
              </Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
} 