import {
    Entity,
    Column,
    PrimaryGeneratedColumn,
    CreateDateColumn,
    ManyToOne,
    JoinColumn,
} from 'typeorm';
import { User } from '../../user/entities/user.entity';

export enum MediaType {
    IMAGE = 'image',
    DOCUMENT = 'document',
}

@Entity('media')
export class Media {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column()
    filename: string;

    @Column()
    originalName: string;

    @Column()
    mimeType: string;

    @Column('bigint')
    size: number;

    @Column()
    s3Key: string;

    @Column()
    s3Url: string;

    @Column({
        type: 'enum',
        enum: MediaType,
    })
    type: MediaType;

    @Column({ name: 'uploaded_by_user_id' })
    uploadedByUserId: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'uploaded_by_user_id' })
    uploadedByUser: User;

    @CreateDateColumn({ type: 'timestamptz' })
    createdAt: Date;
}
