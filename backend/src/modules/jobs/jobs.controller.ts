import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { JobsService } from './jobs.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('jobs')
@Controller('jobs')
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Crear trabajo' })
  async create(@Req() req: any, @Body() data: any) {
    const job = await this.jobsService.create(req.user.id, data);
    return { success: true, message: 'Trabajo publicado', data: job };
  }

  @Get()
  @ApiOperation({ summary: 'Listar trabajos' })
  async findAll(@Query() query: any) {
    const result = await this.jobsService.findAll(query);
    return { success: true, data: result.jobs, meta: result.meta };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Detalle de trabajo' })
  async findOne(@Param('id') id: string) {
    const job = await this.jobsService.findById(id);
    return { success: true, data: job };
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Actualizar trabajo' })
  async update(@Param('id') id: string, @Req() req: any, @Body() data: any) {
    const job = await this.jobsService.update(id, req.user.id, data);
    return { success: true, message: 'Trabajo actualizado', data: job };
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Eliminar trabajo' })
  async remove(@Param('id') id: string, @Req() req: any) {
    await this.jobsService.delete(id, req.user.id);
    return { success: true, message: 'Trabajo eliminado' };
  }
}
