import { Request, Response } from 'express';
import { VPS } from '../models/VPS';

export class VPSController {
  getAll = async (req: Request, res: Response) => {
    try {
      const vpsList = await VPS.find();
      res.json(vpsList);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching VPS list' });
    }
  };

  getOne = async (req: Request, res: Response) => {
    try {
      const vps = await VPS.findById(req.params.id);
      if (!vps) {
        return res.status(404).json({ message: 'VPS not found' });
      }
      res.json(vps);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching VPS' });
    }
  };

  create = async (req: Request, res: Response) => {
    try {
      const vps = new VPS({
        ...req.body,
        startDate: new Date(),
        endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
      });
      await vps.save();
      res.status(201).json(vps);
    } catch (error) {
      res.status(500).json({ message: 'Error creating VPS' });
    }
  };

  update = async (req: Request, res: Response) => {
    try {
      const vps = await VPS.findByIdAndUpdate(req.params.id, req.body, { new: true });
      if (!vps) {
        return res.status(404).json({ message: 'VPS not found' });
      }
      res.json(vps);
    } catch (error) {
      res.status(500).json({ message: 'Error updating VPS' });
    }
  };

  delete = async (req: Request, res: Response) => {
    try {
      const vps = await VPS.findByIdAndDelete(req.params.id);
      if (!vps) {
        return res.status(404).json({ message: 'VPS not found' });
      }
      res.status(204).send();
    } catch (error) {
      res.status(500).json({ message: 'Error deleting VPS' });
    }
  };
} 