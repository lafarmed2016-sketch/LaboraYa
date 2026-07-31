import { Controller, Post, Get, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('reviews')
@Controller('reviews')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ReviewsController {
  constructor(private readonly service: ReviewsService) {}

  @Post()
  @ApiOperation({ summary: 'Crear calificación' })
  async create(@Req() req: any, @Body() body: any) {
    const review = await this.service.createReview(req.user.id, body);
    return { success: true, message: 'Calificación enviada', data: review };
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Calificaciones de un usuario' })
  async getByUser(@Param('userId') userId: string, @Query('page') page = 1) {
    const result = await this.service.getByUser(userId, +page);
    return { success: true, data: result.reviews, meta: result.meta };
  }
}
