import { Controller, Get, Put, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ContractsService } from './contracts.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('contracts')
@Controller('contracts')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ContractsController {
  constructor(private readonly service: ContractsService) {}

  @Get()
  @ApiOperation({ summary: 'Mis contratos' })
  async getMyContracts(@Req() req: any, @Query('role') role: 'worker' | 'employer' = 'worker') {
    const contracts = await this.service.getMyContracts(req.user.id, role);
    return { success: true, data: contracts };
  }

  @Put(':id/status')
  @ApiOperation({ summary: 'Actualizar estado del contrato' })
  async updateStatus(@Param('id') id: string, @Req() req: any, @Body() body: { status: string; note?: string }) {
    const result = await this.service.updateStatus(id, req.user.id, body.status, body.note);
    return { success: true, message: 'Estado actualizado', data: result };
  }
}
