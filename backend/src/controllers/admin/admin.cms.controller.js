import CMS from "../../models/shop/CMSContent.model.js";

export const create = async (req, res) => {
  res.json(await CMS.create(req.body));
};

export const getAll = async (req, res) => {
  res.json(await CMS.find());
};

export const update = async (req, res) => {
  res.json(await CMS.findByIdAndUpdate(req.params.id, req.body, { new: true }));
};
