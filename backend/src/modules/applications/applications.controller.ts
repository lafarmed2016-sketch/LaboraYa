import { Controller, Post, Get, Put, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ApplicationsService } from './applications.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('applications')
@Controller('applications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ApplicationsController {
  constructor(private readonly service: ApplicationsService) {}

  @Post()
  @ApiOperation({ summary: 'Postularse a un trabajo' })
  async apply(@Req() req: any, @Body() body: any) {
    const result = await this.service.apply(req.user.id, body);
    return { success: true, message: 'Postulación enviada', data: result };
  }

  @Get('mine')
  @ApiOperation({ summary: 'Mis postulaciones' })
  async getMyApplications(@Req() req: any, @Query('page') page = 1, @Query('limit') limit = 20) {
    const result = await this.service.getMyApplications(req.user.id, +page, +limit);
    return { success: true, data: result.applications, meta: result.meta };
  }

  @Get('job/:jobId')
  @ApiOperation({ summary: 'Postulaciones por trabajo' })
  async getByJob(@Param('jobId') jobId: string, @Req() req: any) {
    const result = await this.service.getByJob(jobId, req.user.id);
    return { success: true, data: result };
  }

  @Put(':id/status')
  @ApiOperation({ summary: 'Cambiar estado de postulación' })
  async updateStatus(@Param('id') id: string, @Req() req: any, @Body('status') status: string) {
    const result = await this.service.updateStatus(id, req.user.id, status);
    return { success: true, message: 'Estado actualizado', data: result };
  }

  @Put(':id/withdraw')
  @ApiOperation({ summary: 'Retirar postulación' })
  async withdraw(@Param('id') id: string, @Req() req: any) {
    const result = await this.service.withdraw(id, req.user.id);
    return { success: true, message: 'Postulación retirada', data: result };
  }
}
