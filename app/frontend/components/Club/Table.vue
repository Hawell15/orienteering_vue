<template>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('club_name')">Nume</th>
                <th @click="orderTable('territory')">Teritoriu</th>
                <th @click="orderTable('representative')">Reprezentant</th>
                <th @click="orderTable('email')">email</th>
                <th @click="orderTable('phone')">Telefon</th>
                <th @click="orderTable('runners_count')">Numar Sportivi</th>
                <th colspan="3">Actiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`clubs/${element.id}`">{{ element.id }}</a></td>
                <td><a :href="`clubs/${element.id}`">{{ element.club_name }}</a></td>
                <td><a :href="`clubs/${element.id}`">{{ element.territory }}</a></td>
                <td>{{ element.representative }}</td>
                <td>{{ element.email }}</td>
                <td>{{ element.phone }}</td>
                <td><a class="btn btn-sm btn-warning" :href="`clubs/${element.id}`"> Arată </a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :club="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

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
