<template>
    <table class="forest-table">
        <thead>
            <tr>
                <th class="sortable" @click="orderTable('id')">ID</th>
                <th class="sortable" @click="orderTable('club_name')">Nume</th>
                <th class="sortable" @click="orderTable('territory')">Teritoriu</th>
                <th class="sortable" @click="orderTable('representative')">Reprezentant</th>
                <th class="sortable" @click="orderTable('email')">Email</th>
                <th class="sortable" @click="orderTable('phone')">Telefon</th>
                <th class="sortable" @click="orderTable('runners_count')">Sportivi</th>
                <th>Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`/clubs/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`/clubs/${element.id}`">{{ element.club_name }}</a></td>
                <td><a :href="`/clubs/${element.id}`">{{ element.territory }}</a></td>
                <td>{{ element.representative }}</td>
                <td>{{ element.email }}</td>
                <td>{{ element.phone }}</td>
                <td>{{ element.runners_count }}</td>
                <td>
                    <div class="row-actions">
                        <a class="row-action-btn show" :href="`/clubs/${element.id}`">Arată</a>
                        <button class="row-action-btn edit" @click="editElement(element)">Editează</button>
                        <button class="row-action-btn delete" @click="deleteElement(element.id)">Șterge</button>
                    </div>
                </td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :club="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast club?')) {
        axios.delete(`/clubs/${id}`).then(() => {
            props.elements = props.elements.filter(club => club.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/clubs/${elementData.id}.json`, { club: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>

<style scoped src="../shared/index.css"></style>
