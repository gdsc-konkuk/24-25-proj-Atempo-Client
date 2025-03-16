'use client'

import { Box, Typography, Grid, Paper } from '@mui/material';
import SchoolIcon from '@mui/icons-material/School';
import FlightIcon from '@mui/icons-material/Flight';
import MusicNoteIcon from '@mui/icons-material/MusicNote';
import MovieIcon from '@mui/icons-material/Movie';
import WorkIcon from '@mui/icons-material/Work';
import RestaurantIcon from '@mui/icons-material/Restaurant';

const themes = [
  { icon: <SchoolIcon />, title: '학교 생활', color: '#e8f5e9', badge: '초급' },
  { icon: <WorkIcon />, title: '회사 생활', color: '#fff3e0', badge: '중급' },
  { icon: <FlightIcon />, title: '여행', color: '#e3f2fd', badge: '초급' },
  { icon: <MusicNoteIcon />, title: 'K-POP', color: '#fce4ec', badge: '중급' },
  { icon: <MovieIcon />, title: '한국 드라마', color: '#f3e5f5', badge: '중급' },
  { icon: <RestaurantIcon />, title: '음식과 맛집', color: '#fff3e0', badge: '초급' }
];

export default function RecommendedThemes() {
  return (
    <Box sx={{ mt: 4 }}>
      <Typography variant="h6" sx={{ mb: 2 }}>추천 테마</Typography>
      <Grid container spacing={2}>
        {themes.map((theme, index) => (
          <Grid item xs={6} md={4} key={index}>
            <Paper
              sx={{
                p: 2,
                display: 'flex',
                alignItems: 'center',
                bgcolor: theme.color,
                cursor: 'pointer',
                '&:hover': {
                  transform: 'translateY(-2px)',
                  transition: 'transform 0.2s'
                }
              }}
            >
              <Box sx={{ mr: 1 }}>{theme.icon}</Box>
              <Box>
                <Typography variant="body2">{theme.title}</Typography>
                <Typography 
                  variant="caption" 
                  sx={{ 
                    color: 'text.secondary',
                    bgcolor: 'rgba(0,0,0,0.05)',
                    px: 1,
                    borderRadius: 1
                  }}
                >
                  {theme.badge}
                </Typography>
              </Box>
            </Paper>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
} 