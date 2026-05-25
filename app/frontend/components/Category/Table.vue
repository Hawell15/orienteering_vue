<template>
    <table class="forest-table">
        <thead>
            <tr>
                <th class="sortable" @click="orderTable('id')">ID</th>
                <th class="sortable" @click="orderTable('category_name')">Nume</th>
                <th class="sortable" @click="orderTable('full_name')">Nume complet</th>
                <th class="sortable" @click="orderTable('points')">Puncte</th>
                <th class="sortable" @click="orderTable('validaty_period')">Validitate (ani)</th>
                <th class="sortable" @click="orderTable('runners_count')">Sportivi</th>
                <th>Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`/categories/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`/categories/${element.id}`">{{ element.category_name }}</a></td>
                <td><a :href="`/categories/${element.id}`">{{ element.full_name }}</a></td>
                <td>{{ element.points }}</td>
                <td>{{ element.validaty_period }}</td>
                <td><a :href="`/runners?category_id=${element.id}`">{{ element.runners_count }}</a></td>
                <td>
                    <div class="row-actions">
                        <a class="row-action-btn show" :href="`/categories/${element.id}`">Arată</a>
                        <button class="row-action-btn edit" @click="editElement(element)">Editează</button>
                        <button class="row-action-btn delete" @click="deleteElement(element.id)">Șterge</button>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :category="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order', 'deleted', 'updated'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi această categorie?')) {
        axios.delete(`/categories/${id}`).then(() => {
            emit('deleted', id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/categories/${elementData.id}.json`, { category: elementData }).then(res => {
        emit('updated', res.data)
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>

<style scoped src="../shared/index.css"></style>
