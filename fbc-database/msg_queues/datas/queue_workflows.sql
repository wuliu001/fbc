USE `msg_queues`;

TRUNCATE TABLE `queue_workflows`;

/* single queue column queue_type must at the same as column dst_queue_type */
INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (1,'test',null,null,0,null,'/msg/test','POST',0,0,'test',0,0,0,'sync testdata');
INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (2,'test',null,null,1,null,null,null,0,1,null,null,0,0,'end step');

INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (3,'syncBlockCache',null,null,0,null,null,null,0,0,null,null,0,0,'sync block cache');
INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (4,'syncBlockCache',null,null,1,null,'/goods','POST',0,0,'syncBlockCache',1,0,0,'sync block cache');
INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (5,'syncBlockCache',null,null,2,null,null,null,0,1,null,null,0,0,'end step');

INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (6,'syncPurchase',null,null,0,null,null,null,0,0,null,null,0,0,'sync cache purchase');
INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (7,'syncPurchase',null,null,1,null,'/transactions/purchase/fruit','POST',0,0,'syncPurchase',1,0,0,'sync cache purchase');
INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (8,'syncPurchase',null,null,2,null,null,null,0,1,null,null,0,0,'end step');

INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (9,'deletePurchase',null,null,0,null,null,null,0,0,null,null,0,0,'sync cache purchase');
INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (10,'deletePurchase',null,null,1,null,'/transactions/purchase/fruit','PUT',0,0,'deletePurchase',1,0,0,'delete cache purchase');
INSERT INTO `queue_workflows`(id, queue_type, sub_queue_type, success_percent, queue_step, special_step, uri, method, repeat_count, is_end_step, dst_queue_type, dst_queue_step, `limit`, double_side, remark) VALUES (11,'deletePurchase',null,null,2,null,null,null,0,1,null,null,0,0,'end step');

INSERT INTO `msg_queues`.`queue_workflows` (`queue_type`, `sub_queue_type`, `success_percent`, `queue_step`, `special_step`, `repeat_count`, `is_end_step`, `dst_queue_type`, `dst_queue_step`, `limit`, `double_side`) VALUES ('packingCache', 'spreadPackingCache', '100', '0', '{\"0\":1,\"1\":0}', '0', '0', NULL, NULL, '0', '0');
INSERT INTO `msg_queues`.`queue_workflows` (`queue_type`, `queue_step`, `special_step`, `repeat_count`, `is_end_step`, `limit`, `double_side`) VALUES ('packingCache', '1', '{\"0\":2,\"1\":1}', '0', '0', '0', '0');
INSERT INTO `msg_queues`.`queue_workflows` (`queue_type`, `queue_step`,`special_step`, `repeat_count`, `is_end_step`, `limit`, `double_side`) VALUES ('packingCache', '2',null, '0', '1', '0', '0');

INSERT INTO `msg_queues`.`queue_workflows` (`queue_type`, `queue_step`, `special_step`, `uri`, `method`, `repeat_count`, `is_end_step`, `dst_queue_type`, `dst_queue_step`, `limit`, `double_side`) VALUES ('spreadPackingCache', '0', '{\"0\":1,\"1\":0}', '/msg_queues/packing', 'POST', '0', '0', 'spreadPackingCache', '0', '0', '0');
INSERT INTO `msg_queues`.`queue_workflows` (`queue_type`, `queue_step`,`special_step`, `repeat_count`, `is_end_step`, `limit`, `double_side`) VALUES ('spreadPackingCache', '1','{\"0\":2,\"1\":1}', '0', '0', '0', '0');
INSERT INTO `msg_queues`.`queue_workflows` (`queue_type`, `queue_step`, `repeat_count`, `is_end_step`, `limit`, `double_side`) VALUES ('spreadPackingCache', '2', '0', '1', '0', '0');



TRUNCATE TABLE service_parameters;
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `body_val_pos`, `parameter_val_pos`) VALUES (1,'test', 0,  1, 3);
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `body_val_pos`, `parameter_val_pos`) VALUES (2,'syncBlockCache', 1, 1, null);
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `body_val_pos`, `parameter_val_pos`) VALUES (3,'syncPurchase', 1, 1, null);
INSERT INTO `service_parameters` (`id`, `queue_type`, `queue_step`, `body_val_pos`, `parameter_val_pos`) VALUES (4,'deletePurchase', 1, 1,2);
INSERT INTO `service_parameters` (`queue_type`, `queue_step`, `body_val_pos`) VALUES ('spreadPackingCache', '0', '1');


TRUNCATE TABLE job_config;
INSERT INTO `job_config`(queue_type, queue_step, proc_name, `type`) VALUES('spreadPackingCache', 1, 'blockchain_cache.`spreadPackingCache.confirm`', 'success');