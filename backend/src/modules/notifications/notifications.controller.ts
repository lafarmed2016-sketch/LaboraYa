import { Controller, Get, Put, Param, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: 'Mis notificaciones' })
  async getAll(@Req() req: any, @Query('page') page = 1) {
    const result = await this.service.getByUser(req.user.id, +page);
    return { success: true, data: result.notifications, meta: result.meta };
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Cantidad de no leídas' })
  async getUnreadCount(@Req() req: any) {
    const count = await this.service.getUnreadCount(req.user.id);
    return { success: true, data: { count } };
  }

  @Put(':id/read')
  @ApiOperation({ summary: 'Marcar como leída' })
  async markAsRead(@Param('id') id: string, @Req() req: any) {
    await this.service.markAsRead(id, req.user.id);
    return { success: true, message: 'Notificación leída' };
  }

  @Put('read-all')
  @ApiOperation({ summary: 'Marcar todas como leídas' })
  async markAllAsRead(@Req() req: any) {
    await this.service.markAllAsRead(req.user.id);
    return { success: true, message: 'Todas las notificaciones marcadas como leídas' };
  }
}
