import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async createReview(reviewerId: string, data: {
    contractId: string;
    rating: number;
    comment?: string;
    quality?: number;
    punctuality?: number;
    communication?: number;
    professionalism?: number;
    compliance?: number;
  }) {
    const contract = await this.prisma.contract.findUnique({ where: { id: data.contractId } });
    if (!contract) throw new NotFoundException('Contrato no encontrado');
    if (contract.status !== 'COMPLETED') throw new ForbiddenException('El contrato debe estar completado');

    if (contract.workerId !== reviewerId && contract.employerId !== reviewerId) {
      throw new ForbiddenException('No autorizado');
    }

    const reviewedId = contract.workerId === reviewerId ? contract.employerId : contract.workerId;

    const existing = await this.prisma.review.findUnique({
      where: { contractId_reviewerId: { contractId: data.contractId, reviewerId } },
    });
    if (existing) throw new ConflictException('Ya calificaste este contrato');

    const review = await this.prisma.review.create({
      data: { ...data, reviewerId, reviewedId },
    });

    // Update average rating
    const reviews = await this.prisma.review.findMany({ where: { reviewedId } });
    const avgRating = reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

    // Update worker or employer profile
    const workerProfile = await this.prisma.workerProfile.findUnique({ where: { userId: reviewedId } });
    if (workerProfile) {
      await this.prisma.workerProfile.update({
        where: { userId: reviewedId },
        data: { averageRating: avgRating, totalReviews: reviews.length },
      });
    }

    const employerProfile = await this.prisma.employerProfile.findUnique({ where: { userId: reviewedId } });
    if (employerProfile) {
      await this.prisma.employerProfile.update({
        where: { userId: reviewedId },
        data: { averageRating: avgRating, totalReviews: reviews.length },
      });
    }

    return review;
  }

  async getByUser(userId: string, page = 1, limit = 20) {
    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { reviewedId: userId, visible: true },
        include: {
          reviewer: { select: { firstName: true, lastName: true, avatar: true } },
          contract: { include: { job: { select: { title: true } } } },
        },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.review.count({ where: { reviewedId: userId, visible: true } }),
    ]);

    return { reviews, meta: { page, limit, total, totalPages: Math.ceil(total / limit) } };
  }
}
