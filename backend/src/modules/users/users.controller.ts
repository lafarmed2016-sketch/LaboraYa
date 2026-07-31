import { Controller, Get, Put, Delete, Body, Param, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('users')
@Controller('users')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Obtener perfil del usuario actual' })
  async getProfile(@Req() req: any) {
    const user = await this.usersService.findById(req.user.id);
    return { success: true, data: user };
  }

  @Put('profile')
  @ApiOperation({ summary: 'Actualizar perfil' })
  async updateProfile(@Req() req: any, @Body() data: any) {
    const user = await this.usersService.updateProfile(req.user.id, data);
    return { success: true, message: 'Perfil actualizado', data: user };
  }

  @Delete('account')
  @ApiOperation({ summary: 'Eliminar cuenta' })
  async deleteAccount(@Req() req: any) {
    await this.usersService.deleteAccount(req.user.id);
    return { success: true, message: 'Cuenta eliminada' };
  }
}
