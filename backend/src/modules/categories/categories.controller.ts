import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PrismaService } from '../../prisma/prisma.service';

@ApiTags('categories')
@Controller('categories')
export class CategoriesController {
  constructor(private prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'Listar categorías' })
  async findAll() {
    const categories = await this.prisma.category.findMany({
      where: { active: true },
      include: { subcategories: { where: { active: true } } },
      orderBy: { order: 'asc' },
    });
    return { success: true, data: categories };
  }
}
