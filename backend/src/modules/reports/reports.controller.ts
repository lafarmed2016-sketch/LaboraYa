import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('reports')
@Controller('reports')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ReportsController {
  constructor(private prisma: PrismaService) {}

  @Post()
  @ApiOperation({ summary: 'Crear reporte' })
  async create(@Req() req: any, @Body() body: { reportedId?: string; jobId?: string; reason: string; description?: string }) {
    const report = await this.prisma.report.create({
      data: { reporterId: req.user.id, ...body, reason: body.reason as any },
    });
    return { success: true, message: 'Reporte enviado. Lo revisaremos pronto.', data: report };
  }
}
