import { Controller, Get, Post, Body, Param, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';

@ApiTags('chat')
@Controller('chats')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get()
  @ApiOperation({ summary: 'Listar conversaciones' })
  async getConversations(@Req() req: any) {
    const conversations = await this.chatService.getConversations(req.user.id);
    return { success: true, data: conversations };
  }

  @Post()
  @ApiOperation({ summary: 'Crear o obtener conversación' })
  async getOrCreate(@Req() req: any, @Body() body: { otherUserId: string; jobId?: string }) {
    const conversation = await this.chatService.getOrCreateConversation(req.user.id, body.otherUserId, body.jobId);
    return { success: true, data: conversation };
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Obtener mensajes' })
  async getMessages(@Param('id') id: string, @Req() req: any, @Query('page') page = 1) {
    const result = await this.chatService.getMessages(id, req.user.id, +page);
    return { success: true, data: result.messages, meta: result.meta };
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Enviar mensaje' })
  async sendMessage(@Param('id') id: string, @Req() req: any, @Body() body: { content: string; type?: string }) {
    const message = await this.chatService.sendMessage(id, req.user.id, body.content, body.type);
    return { success: true, data: message };
  }
}
