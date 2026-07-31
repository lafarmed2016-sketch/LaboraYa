import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class JobsService {
  constructor(private prisma: PrismaService) {}

  async create(publisherId: string, data: any) {
    return this.prisma.job.create({
      data: { ...data, publisherId, status: 'PUBLISHED', publishedAt: new Date() },
    });
  }

  async findAll(query: any) {
    const { page = 1, limit = 20, categoryId, modality, isUrgent } = query;
    const where: any = { status: 'PUBLISHED', deletedAt: null };
    if (categoryId) where.categoryId = categoryId;
    if (modality) where.modality = modality;
    if (isUrgent) where.isUrgent = true;

    const [jobs, total] = await Promise.all([
      this.prisma.job.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: { category: true, images: true, publisher: { select: { id: true, firstName: true, lastName: true, avatar: true } } },
      }),
      this.prisma.job.count({ where }),
    ]);

    return { jobs, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
  }

  async findById(id: string) {
    const job = await this.prisma.job.findUnique({
      where: { id },
      include: { category: true, subcategory: true, images: true, publisher: { select: { id: true, firstName: true, lastName: true, avatar: true } } },
    });
    if (!job) throw new NotFoundException('Trabajo no encontrado');
    return job;
  }

  async update(id: string, userId: string, data: any) {
    const job = await this.prisma.job.findUnique({ where: { id } });
    if (!job) throw new NotFoundException('Trabajo no encontrado');
    if (job.publisherId !== userId) throw new ForbiddenException('No autorizado');
    return this.prisma.job.update({ where: { id }, data });
  }

  async delete(id: string, userId: string) {
    const job = await this.prisma.job.findUnique({ where: { id } });
    if (!job) throw new NotFoundException('Trabajo no encontrado');
    if (job.publisherId !== userId) throw new ForbiddenException('No autorizado');
    return this.prisma.job.update({ where: { id }, data: { deletedAt: new Date() } });
  }
}
