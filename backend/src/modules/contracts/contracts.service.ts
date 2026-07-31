import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ContractsService {
  constructor(private prisma: PrismaService) {}

  async getMyContracts(userId: string, role: 'worker' | 'employer') {
    const where = role === 'worker' ? { workerId: userId } : { employerId: userId };
    return this.prisma.contract.findMany({
      where,
      include: {
        job: { select: { title: true, address: true, modality: true } },
        worker: { select: { id: true, firstName: true, lastName: true, avatar: true } },
        employer: { select: { id: true, firstName: true, lastName: true, avatar: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateStatus(contractId: string, userId: string, status: string, note?: string) {
    const contract = await this.prisma.contract.findUnique({ where: { id: contractId } });
    if (!contract) throw new NotFoundException('Contrato no encontrado');

    if (contract.workerId !== userId && contract.employerId !== userId) {
      throw new ForbiddenException('No autorizado');
    }

    // Validar transiciones
    const validTransitions: Record<string, string[]> = {
      PENDING: ['ACCEPTED', 'CANCELLED'],
      ACCEPTED: ['CONFIRMED', 'CANCELLED'],
      CONFIRMED: ['IN_PROGRESS', 'CANCELLED'],
      IN_PROGRESS: ['PENDING_CONFIRMATION', 'CANCELLED', 'IN_DISPUTE'],
      PENDING_CONFIRMATION: ['COMPLETED', 'IN_DISPUTE'],
    };

    const allowed = validTransitions[contract.status] || [];
    if (!allowed.includes(status)) {
      throw new BadRequestException(`No se puede cambiar de ${contract.status} a ${status}`);
    }

    const updateData: any = { status };
    if (status === 'IN_PROGRESS') updateData.startedAt = new Date();
    if (status === 'COMPLETED') {
      updateData.completedAt = new Date();
      await this.prisma.job.update({
        where: { id: contract.jobId },
        data: { status: 'COMPLETED' },
      });
    }
    if (status === 'CANCELLED') {
      updateData.cancelledAt = new Date();
      updateData.cancelReason = note;
    }

    const updated = await this.prisma.contract.update({ where: { id: contractId }, data: updateData });

    // Log status change
    await this.prisma.contractStatusHistory.create({
      data: { contractId, status: status as any, changedBy: userId, note },
    });

    return updated;
  }
}
