import { IsEmail, IsNotEmpty, IsString, MinLength, IsOptional, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({ example: 'Juan' })
  @IsNotEmpty({ message: 'El nombre es obligatorio' })
  @IsString()
  firstName: string;

  @ApiProperty({ example: 'Pérez' })
  @IsNotEmpty({ message: 'El apellido es obligatorio' })
  @IsString()
  lastName: string;

  @ApiProperty({ example: 'juan@correo.com' })
  @IsEmail({}, { message: 'Correo electrónico inválido' })
  email: string;

  @ApiProperty({ example: '987654321' })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({ example: 'MiPassword123!' })
  @IsNotEmpty({ message: 'La contraseña es obligatoria' })
  @MinLength(8, { message: 'La contraseña debe tener al menos 8 caracteres' })
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*])/, {
    message: 'La contraseña debe incluir mayúscula, minúscula, número y carácter especial',
  })
  password: string;

  @ApiProperty({ example: 'Lima' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiProperty({ example: 'BOTH', enum: ['WORKER', 'EMPLOYER', 'BOTH'] })
  @IsNotEmpty()
  @IsString()
  userType: string;
}
