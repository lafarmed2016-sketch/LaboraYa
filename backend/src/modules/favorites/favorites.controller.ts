import { Controller, Post, Get, Delete, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('favorites')
@Controller('favorites')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class FavoritesController {
  constructor(private prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Mis favoritos' })
  async getAll(@Req() req: any) {
    const favorites = await this.prisma.favorite.findMany({
      where: { userId: req.user.id },
      include: { job: { include: { category: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return { success: true, data: favorites };
  }

  @Post()
  @ApiOperation({ summary: 'Agregar a favoritos' })
  async add(@Req() req: any, @Body() body: { jobId?: string; targetId?: string; type: string }) {
    const favorite = await this.prisma.favorite.create({
      data: { userId: req.user.id, ...body },
    });
    return { success: true, message: 'Agregado a favoritos', data: favorite };
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Eliminar de favoritos' })
  async remove(@Param('id') id: string) {
    await this.prisma.favorite.delete({ where: { id } });
    return { success: true, message: 'Eliminado de favoritos' };
  }
}
