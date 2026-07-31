import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  async getConversations(userId: string) {
    const participants = await this.prisma.conversationParticipant.findMany({
      where: { userId },
      include: {
        conversation: {
          include: {
            participants: {
              include: { user: { select: { id: true, firstName: true, lastName: true, avatar: true } } },
            },
            messages: { orderBy: { createdAt: 'desc' }, take: 1 },
          },
        },
      },
      orderBy: { conversation: { updatedAt: 'desc' } },
    });

    return participants.map((p) => ({
      id: p.conversation.id,
      participants: p.conversation.participants
        .filter((pp) => pp.userId !== userId)
        .map((pp) => pp.user),
      lastMessage: p.conversation.messages[0] || null,
      lastReadAt: p.lastReadAt,
      updatedAt: p.conversation.updatedAt,
    }));
  }

  async getOrCreateConversation(userId: string, otherUserId: string, jobId?: string) {
    // Check if conversation exists
    const existing = await this.prisma.conversation.findFirst({
      where: {
        AND: [
          { participants: { some: { userId } } },
          { participants: { some: { userId: otherUserId } } },
        ],
      },
    });

    if (existing) return existing;

    // Create new conversation
    return this.prisma.conversation.create({
      data: {
        jobId,
        participants: {
          create: [{ userId }, { userId: otherUserId }],
        },
      },
    });
  }

  async getMessages(conversationId: string, userId: string, page = 1, limit = 50) {
    // Verify user is participant
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!participant) throw new ForbiddenException('No autorizado');

    const [messages, total] = await Promise.all([
      this.prisma.message.findMany({
        where: { conversationId, deletedForAll: false },
        include: {
          sender: { select: { id: true, firstName: true, lastName: true, avatar: true } },
          attachments: true,
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.message.count({ where: { conversationId, deletedForAll: false } }),
    ]);

    // Mark as read
    await this.prisma.conversationParticipant.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { lastReadAt: new Date() },
    });

    return { messages: messages.reverse(), meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
  }

  async sendMessage(conversationId: string, senderId: string, content: string, type = 'TEXT') {
    const participant = await this.prisma.conversationParticipant.findUnique({
      where: { conversationId_userId: { conversationId, userId: senderId } },
    });
    if (!participant) throw new ForbiddenException('No autorizado');

    const message = await this.prisma.message.create({
      data: { conversationId, senderId, content, type: type as any },
      include: {
        sender: { select: { id: true, firstName: true, lastName: true, avatar: true } },
      },
    });

    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    return message;
  }

  async markAsRead(conversationId: string, userId: string) {
    await this.prisma.conversationParticipant.update({
      where: { conversationId_userId: { conversationId, userId } },
      data: { lastReadAt: new Date() },
    });
  }
}
