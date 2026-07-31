import { Injectable, NotFoundException, ConflictException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ApplicationsService {
  constructor(private prisma: PrismaService) {}

  async apply(applicantId: string, data: { jobId: string; message?: string; proposedBudget?: number; estimatedTime?: string }) {
    const job = await this.prisma.job.findUnique({ where: { id: data.jobId } });
    if (!job) throw new NotFoundException('Trabajo no encontrado');
    if (job.publisherId === applicantId) throw new ForbiddenException('No puedes postularte a tu propio trabajo');

    const existing = await this.prisma.application.findUnique({
      where: { jobId_applicantId: { jobId: data.jobId, applicantId } },
    });
    if (existing) throw new ConflictException('Ya te postulaste a este trabajo');

    const application = await this.prisma.application.create({
      data: { ...data, applicantId },
    });

    await this.prisma.job.update({
      where: { id: data.jobId },
      data: { applicantsCount: { increment: 1 } },
    });

    return application;
  }

  async getByJob(jobId: string, userId: string) {
    const job = await this.prisma.job.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundException('Trabajo no encontrado');
    if (job.publisherId !== userId) throw new ForbiddenException('No autorizado');

    return this.prisma.application.findMany({
      where: { jobId },
      include: {
        applicant: { select: { id: true, firstName: true, lastName: true, avatar: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getMyApplications(userId: string, page = 1, limit = 20) {
    const [applications, total] = await Promise.all([
      this.prisma.application.findMany({
        where: { applicantId: userId },
        include: {
          job: { include: { category: true, publisher: { select: { firstName: true, lastName: true } } } },
        },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.application.count({ where: { applicantId: userId } }),
    ]);

    return { applications, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
  }

  async updateStatus(applicationId: string, userId: string, status: string) {
    const application = await this.prisma.application.findUnique({
      where: { id: applicationId },
      include: { job: true },
    });
    if (!application) throw new NotFoundException('Postulación no encontrada');
    if (application.job.publisherId !== userId) throw new ForbiddenException('No autorizado');

    const updated = await this.prisma.application.update({
      where: { id: applicationId },
      data: { status: status as any, respondedAt: new Date() },
    });

    // Si se acepta, crear contrato
    if (status === 'ACCEPTED') {
      await this.prisma.contract.create({
        data: {
          jobId: application.jobId,
          applicationId: application.id,
          workerId: application.applicantId,
          employerId: application.job.publisherId,
          agreedBudget: application.proposedBudget,
          status: 'PENDING',
        },
      });

      await this.prisma.job.update({
        where: { id: application.jobId },
        data: { status: 'ASSIGNED' },
      });
    }

    return updated;
  }

  async withdraw(applicationId: string, userId: string) {
    const application = await this.prisma.application.findUnique({ where: { id: applicationId } });
    if (!application) throw new NotFoundException('Postulación no encontrada');
    if (application.applicantId !== userId) throw new ForbiddenException('No autorizado');

    return this.prisma.application.update({
      where: { id: applicationId },
      data: { status: 'WITHDRAWN' },
    });
  }
}
